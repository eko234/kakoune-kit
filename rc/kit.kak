define-command -hidden kit-select %{
    unmap window normal a
    unmap window normal d
    unmap window normal r
    try %{
        # Select paths
        execute-keys '<a-x>s^[ !\?ACDMRTU]{2} <ret><a-:>l<a-l>S -> <ret>'
        map window normal -docstring add a ': kit-add<ret>'
        map window normal -docstring diff d ': git diff -- %val{selections}<a-!><ret>'
        map window normal -docstring subtract r ': kit-subtract<ret>'
    } catch %{
        # Select truncated SHA-1
        execute-keys '<a-x>s^[0-9a-f]{7}<ret>'
        map window normal -docstring show d ': git show %val{selections}<a-!><ret>'
    } catch nop
}


define-command -hidden kit-rebuild %{
    set-option buffer readonly false
    execute-keys '%"_cRecent commits:<ret>'
    execute-keys '<a-;>!git log -6 --oneline<ret><ret><esc>'
    execute-keys '|git status -zb<ret>s\0<ret>r<ret>ghj'
    try %{ execute-keys 'sR<ret>LLdjPkxdp<a-J>i -><esc>%' }
    set-option buffer readonly true
    kit-select
}

define-command kit %{
    edit -scratch *kit*
    set-option buffer filetype kit
    kit-rebuild
}

define-command -hidden kit-refresh %{
    execute-keys '*: kit-rebuild; try %{exec s<lt>ret<gt>}<ret>'
}


define-command -hidden kit-add %{
    evaluate-commands -itersel %{
        nop %sh{ git add -- "$(git rev-parse --show-toplevel)/$kak_selection" }
    }
    kit-refresh
}


define-command -hidden kit-subtract %{
    evaluate-commands -itersel %{
        nop %sh{
            target="$(git rev-parse --show-toplevel)/$kak_selection"
            git reset -- "$target" || git restore --staged -- "$target"
        }
    }
    kit-refresh
}


hook -group kit global WinSetOption filetype=kit %{
    add-highlighter window/kit group
    add-highlighter window/kit/ regex '^Recent commits:$' 0:title
    add-highlighter window/kit/ regex '^[0-9a-f]{7} ' 0:comment
    add-highlighter window/kit/ regex '^(##) (\S+)(( \[[^\n]+\]))?' 1:comment 2:builtin 3:keyword
    add-highlighter window/kit/ regex '^(?:(A)|(C)|([D!?])|([MU])|(R)|(T))[ !\?ACDMRTU] (?:.+?)$' 1:green 2:blue 3:red 4:yellow 5:cyan 6:cyan
    add-highlighter window/kit/ regex '^[ !\?ACDMRTU](?:(A)|(C)|([D!?])|([MU])|(R)|(T)) (?:.+?)$' 1:green 2:blue 3:red 4:yellow 5:cyan 6:cyan
    add-highlighter window/kit/ regex '^R[ !\?ACDMRTU] [^\n]+( -> )' 1:cyan

    hook -group kit window NormalKey '[JKjkhlHLxX%]' kit-select

    map window normal c ': git commit<ret>'
    map window normal l ': git log<ret>'
    map window normal \; ': kit-select<ret>'
    map window normal <a-x> ': kit-select<ret>'
    map window normal x '<a-:>5L4H<a-;>Zgh3L<a-z>a<a-:>x: kit-select<ret>'
    map window normal X '<a-:>5L4H<a-;>Zgh3L<a-z>a<a-:>X: kit-select<ret>'

    hook -once -always window WinSetOption filetype=.* %{
        remove-highlighter window/kit
        remove-hooks window kit
        unmap window normal c ': git commit<ret>'
        unmap window normal l ': git log<ret>'
        unmap window normal \; ': kit-select<ret>'
        unmap window normal <a-x> ': kit-select<ret>'
        unmap window normal x '<a-:>5L4H<a-;>Zgh3L<a-z>a<a-:>x: kit-select<ret>'
        unmap window normal X '<a-:>5L4H<a-;>Zgh3L<a-z>a<a-:>X: kit-select<ret>'
        unmap window normal a
        unmap window normal d
        unmap window normal r
        set-option buffer readonly false
    }
}
