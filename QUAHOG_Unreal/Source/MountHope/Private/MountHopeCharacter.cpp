#include "MountHopeCharacter.h"

#include "GameFramework/Controller.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "MountHopeVehiclePawn.h"

AMountHopeCharacter::AMountHopeCharacter()
{
    PrimaryActorTick.bCanEverTick = true;
    GetCharacterMovement()->MaxWalkSpeed = WalkSpeed;
}

void AMountHopeCharacter::SetSprinting(bool bEnableSprint)
{
    GetCharacterMovement()->MaxWalkSpeed = bEnableSprint ? SprintSpeed : WalkSpeed;
}

bool AMountHopeCharacter::EnterVehicle(AMountHopeVehiclePawn* VehiclePawn)
{
    if (bInVehicle || !VehiclePawn || !Controller)
    {
        return false;
    }

    CurrentVehicle = VehiclePawn;
    bInVehicle = true;

    SetActorEnableCollision(false);
    SetActorHiddenInGame(true);
    Controller->Possess(VehiclePawn);
    return true;
}

bool AMountHopeCharacter::ExitVehicle()
{
    if (!bInVehicle || !CurrentVehicle || !Controller)
    {
        return false;
    }

    const FVector ExitLocation = CurrentVehicle->GetSuggestedExitLocation();
    SetActorLocation(ExitLocation);
    SetActorEnableCollision(true);
    SetActorHiddenInGame(false);
    Controller->Possess(this);

    bInVehicle = false;
    CurrentVehicle = nullptr;
    return true;
}
