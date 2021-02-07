    >_ string match '?' a
    a

    >_ string match 'a*b' axxb
    axxb

    >_ string match -i 'a??B' Axxb
    Axxb

    >_ echo 'ok?' | string match '*\?'
    ok?

    # Note that only the second STRING will match here.
    >_ string match 'foo' 'foo1' 'foo' 'foo2'
    foo

    >_ string match -e 'foo' 'foo1' 'foo' 'foo2'
    foo1
    foo
    foo2

    >_ string match 'foo?' 'foo1' 'foo' 'foo2'
    foo1
    foo
    foo2
