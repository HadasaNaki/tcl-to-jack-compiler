#!/usr/bin/env tclsh

if {$argc != 1} {
    puts "Usage: tclsh VMTranslator.tcl <file.vm|directory>"
    exit 1
}

set path [lindex $argv 0]
set is_dir [file isdirectory $path]

set vm_files {}
if {$is_dir} {
    set vm_files [glob -nocomplain -directory $path *.vm]
    set out_path [file join $path "[file tail [file normalize $path]].asm"]
} else {
    lappend vm_files $path
    set out_path "[file rootname $path].asm"
}

if {[llength $vm_files] == 0} {
    puts "No .vm files found."
    exit 1
}

set out [open $out_path w]
set label_counter 0

proc write_arithmetic {cmd} {
    global out label_counter
    
    switch -exact -- $cmd {
        "add" {
            puts $out "@SP\nAM=M-1\nD=M\nA=A-1\nM=M+D"
        }
        "sub" {
            puts $out "@SP\nAM=M-1\nD=M\nA=A-1\nM=M-D"
        }
        "neg" {
            puts $out "@SP\nA=M-1\nM=-M"
        }
        "eq" - "gt" - "lt" {
            set jmp ""
            if {$cmd eq "eq"} { set jmp "JEQ" }
            if {$cmd eq "gt"} { set jmp "JGT" }
            if {$cmd eq "lt"} { set jmp "JLT" }
            
            puts $out "@SP\nAM=M-1\nD=M\nA=A-1\nD=M-D"
            puts $out "@TRUE_$label_counter\nD;$jmp"
            puts $out "@SP\nA=M-1\nM=0"
            puts $out "@CONTINUE_$label_counter\n0;JMP"
            puts $out "(TRUE_$label_counter)\n@SP\nA=M-1\nM=-1"
            puts $out "(CONTINUE_$label_counter)"
            incr label_counter
        }
        "and" {
            puts $out "@SP\nAM=M-1\nD=M\nA=A-1\nM=M&D"
        }
        "or" {
            puts $out "@SP\nAM=M-1\nD=M\nA=A-1\nM=M|D"
        }
        "not" {
            puts $out "@SP\nA=M-1\nM=!M"
        }
        default {
            puts "Unknown arithmetic command: $cmd"
        }
    }
}

proc write_push_pop {cmd segment index file_name} {
    global out
    
    if {$cmd eq "push"} {
        switch -exact -- $segment {
            "constant" {
                puts $out "@$index\nD=A\n@SP\nA=M\nM=D\n@SP\nM=M+1"
            }
            "local" { puts $out "@LCL\nD=M\n@$index\nA=D+A\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1" }
            "argument" { puts $out "@ARG\nD=M\n@$index\nA=D+A\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1" }
            "this" { puts $out "@THIS\nD=M\n@$index\nA=D+A\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1" }
            "that" { puts $out "@THAT\nD=M\n@$index\nA=D+A\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1" }
            "temp" { 
                set addr [expr 5 + $index]
                puts $out "@$addr\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1" 
            }
            "pointer" {
                set symbol [expr {($index == 0) ? "THIS" : "THAT"}]
                puts $out "@$symbol\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1"
            }
            "static" {
                puts $out "@$file_name.$index\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1"
            }
            default {
                puts "Error: Unknown segment '$segment' for push command."
            }
        }
    } elseif {$cmd eq "pop"} {
        switch -exact -- $segment {
            "local" { puts $out "@LCL\nD=M\n@$index\nD=D+A\n@R13\nM=D\n@SP\nAM=M-1\nD=M\n@R13\nA=M\nM=D" }
            "argument" { puts $out "@ARG\nD=M\n@$index\nD=D+A\n@R13\nM=D\n@SP\nAM=M-1\nD=M\n@R13\nA=M\nM=D" }
            "this" { puts $out "@THIS\nD=M\n@$index\nD=D+A\n@R13\nM=D\n@SP\nAM=M-1\nD=M\n@R13\nA=M\nM=D" }
            "that" { puts $out "@THAT\nD=M\n@$index\nD=D+A\n@R13\nM=D\n@SP\nAM=M-1\nD=M\n@R13\nA=M\nM=D" }
            "temp" {
                set addr [expr 5 + $index]
                puts $out "@SP\nAM=M-1\nD=M\n@$addr\nM=D"
            }
            "pointer" {
                set symbol [expr {($index == 0) ? "THIS" : "THAT"}]
                puts $out "@SP\nAM=M-1\nD=M\n@$symbol\nM=D"
            }
            "static" {
                puts $out "@SP\nAM=M-1\nD=M\n@$file_name.$index\nM=D"
            }
            default {
                puts "Error: Unknown segment '$segment' for pop command."
            }
        }
    }
}

foreach vm_file $vm_files {
    set in [open $vm_file r]
    set current_file_name [file rootname [file tail $vm_file]]
    
    while {[gets $in line] >= 0} {
        # Strip comments
        set idx [string first "//" $line]
        if {$idx != -1} {
            set line [string range $line 0 [expr {$idx - 1}]]
        }
        set line [string trim $line]
        
        if {$line eq ""} continue
        
        # Parse command
        set parts [regexp -all -inline {\S+} $line]
        set cmd [lindex $parts 0]
        
        puts $out "// $line"
        
        if {$cmd eq "push" || $cmd eq "pop"} {
            set segment [lindex $parts 1]
            set index [lindex $parts 2]
            write_push_pop $cmd $segment $index $current_file_name
        } else {
            write_arithmetic $cmd
        }
    }
    close $in
}

close $out
puts "Compiled to $out_path"
exit 0
