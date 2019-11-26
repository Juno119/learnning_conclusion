#include "hello_world.h"

namespace CMakeTest
{
HelloWorld::HelloWorld(std::string name) : name(name)
{
}

void HelloWorld::SayHello()
{
    std::cout << "Hello " << this->name << std::endl;
}

void HelloWorld::SayHello(std::string name)
{
    std::cout << "Hello " << name << std::endl;
}

HelloWorld::~HelloWorld()
{
}

} // namespace CMakeTest