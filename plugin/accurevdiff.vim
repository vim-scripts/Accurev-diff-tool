command! -nargs=0 -bar AccuDiff call s:accurev_diff(0)
command! -nargs=0 -bar AccuDiffBasis call s:accurev_diff(1)
command! -nargs=0 -bar AccuDiffBacked call s:accurev_diff(2)
command! -nargs=0 -bar AccuDiffClose call s:diff_close()
command! -nargs=0 -bar Ad call s:accurev_diff(0)
command! -nargs=0 -bar Adbs call s:accurev_diff(1)
command! -nargs=0 -bar Adbk call s:accurev_diff(2)
command! -nargs=0 -bar Adc call s:diff_close()

function! s:generate_filename(basename)
    let suf = 0
    let newname = a:basename
    while findfile(newname, '.') == newname 
        let newname = a:basename . suf
        let suf = suf + 1
    endwhile
    return newname
endfunction

function! s:my_echo(echo_str)
    echo a:echo_str
endfunction

function! s:diff_close()
    if exists("b:bufLoc") && b:bufLoc == "l"
        "call s:my_echo("In left")
        execute "diffoff"
        execute "wincmd l"
        execute "diffoff"
        execute "wincmd h"
        execute "bd"
    elseif exists("b:bufLoc") && b:bufLoc == "r"
        "call s:my_echo("In right")
        execute "diffoff"
        execute "wincmd h"
        execute "diffoff"
        execute "bd"
    else
        call s:my_echo("Need to run in diff window")
    endif
endfunction

function! s:accurev_diff(diff_type)
    let filename = @%
    call s:my_echo(filename)
    
    let base_file = filename . ".diff"
    let diff_file = s:generate_filename(base_file)

    call s:my_echo("gen diff file " . diff_file . " for " . filename)
    if a:diff_type == 0
        let diff_cmd = "accurev diff "
    elseif a:diff_type == 1
        let diff_cmd = "accurev diff -j "
    else
        let diff_cmd = "accurev diff -b "
    endif
    let diff_cmd = diff_cmd . filename . " -- -u > " . diff_file
    call s:my_echo("run " . diff_cmd)
    let cmdout = system(diff_cmd)
    call s:my_echo("execute \"" . diff_cmd . "\" result is " . cmdout)
    
    let diff_true = 0
    "We should have diff file now
    rightbelow vertical split "_tempory_window"
    execute 'edit ' . diff_file
    execute "normal G\<CR>"
    if line(".") > 1
        execute "normal gg\<CR>"
        execute "normal /^---\<CR>"
        " Only normal commands need <CR>
        execute "s/[^ ]*\\(" . escape(filename, '/') . "\\)/\\1/"
        execute "normal /^+++\<CR>"
        execute "s/[^ ]*\\(" . escape(filename, '/') . "\\)/\\1/"
        let diff_true = 1
    endif
    execute "w"
    execute "bd"

    if diff_true
        let base_file = filename . ".tmp"
        let scratch_file = s:generate_filename(base_file)

        let patch_cmd = "patch -R -o " . scratch_file . " " . filename . " < " . diff_file
        " apply the patch
        call s:my_echo("run " . patch_cmd)
        let cmdout = system(patch_cmd)
    endif
    let cmdout = system('rm -f ' . diff_file)

    if diff_true
        execute "vert diffsplit " . scratch_file
        let b:bufLoc = "l"
        execute "wincmd l"
        let b:bufLoc = "r"
    else
        call s:my_echo("no change found")
    endif
endfunction
