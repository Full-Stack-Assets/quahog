#include "MountHopeVehiclePawn.h"

AMountHopeVehiclePawn::AMountHopeVehiclePawn()
{
    PrimaryActorTick.bCanEverTick = false;
}

FVector AMountHopeVehiclePawn::GetSuggestedExitLocation() const
{
    return GetActorLocation() + (GetActorRightVector() * 175.0f) + FVector(0.0f, 0.0f, 20.0f);
}
