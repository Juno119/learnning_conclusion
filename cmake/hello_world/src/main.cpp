#include <iostream>
#include "hello_world.h"

int main(void)
{
    CMakeTest::HelloWorld test;
    test.SayHello();
    test.SayHello("Jim");
    std::cout << "run successfully..." << std::endl;
    return 0;
}