puts "TCL is working correctly!"

set c_code {
#include <stdio.h>
int main() {
    printf("Compiler is working!\n");
    return 0;
}
}

set c_file "test_compiler.c"
set exec_file ".dist/test_compiler.exe"

# Create the C file
set f [open $c_file w]
puts $f $c_code
close $f

puts "Attempting to compile the C code using gcc..."

# Try to compile
if {[catch {exec gcc $c_file -o $exec_file} compile_result]} {
    puts "Error: Compiler is not working or gcc is not in the system PATH."
    puts "Details: $compile_result"
} else {
    puts "Compilation successful!"
    puts "Running the compiled program..."
    
    # Try to run the compiled file
    if {[catch {exec $exec_file} run_result]} {
        puts "Error: Failed to run the compiled program."
        puts "Details: $run_result"
    } else {
        puts "Output from C program: $run_result"
        puts "Success: The compiler and TCL are both working perfectly!"
    }
}
