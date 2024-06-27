#pragma once

#include <bx/engine/core/ecs.hpp>

class CustomSys : public System
{
public:
    void Initialize() override;
    void Shutdown() override;

    void Update() override;
    void Render() override;
};