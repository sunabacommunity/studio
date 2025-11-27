#!/usr/bin/env fish

haxe buildsys.hxml

if test $status -eq 0
    node build $argv
end