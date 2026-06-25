#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "MountHopeCharacter.generated.h"

class AMountHopeVehiclePawn;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMountHopeCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AMountHopeCharacter();

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Character")
    float WalkSpeed = 300.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Character")
    float SprintSpeed = 500.0f;

    UPROPERTY(BlueprintReadOnly, Category = "MountHope|Character")
    bool bInVehicle = false;

    UFUNCTION(BlueprintCallable, Category = "MountHope|Character")
    void SetSprinting(bool bEnableSprint);

    UFUNCTION(BlueprintCallable, Category = "MountHope|Character")
    bool EnterVehicle(AMountHopeVehiclePawn* VehiclePawn);

    UFUNCTION(BlueprintCallable, Category = "MountHope|Character")
    bool ExitVehicle();

protected:
    UPROPERTY(BlueprintReadOnly, Category = "MountHope|Character")
    TObjectPtr<AMountHopeVehiclePawn> CurrentVehicle = nullptr;
};
