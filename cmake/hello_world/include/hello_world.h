#ifndef HELLO_WORLD_H_
#define HELLO_WORLD_H_

#include <string>
#include <iostream>

namespace CMakeTest
{

class HelloWorld
{
public:
    HelloWorld(std::string name = "default");

    void SayHello();
    void SayHello(std::string name);

    std::string name;

    virtual ~HelloWorld();
};

} // namespace CMakeTest

#endif