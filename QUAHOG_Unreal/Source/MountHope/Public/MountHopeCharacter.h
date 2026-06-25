#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "MountHopeCharacter.generated.h"

class AMountHopeVehiclePawn;
class UInputAction;
class UInputMappingContext;
struct FInputActionValue;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMountHopeCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AMountHopeCharacter();

    virtual void BeginPlay() override;
    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

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
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Input")
    TObjectPtr<UInputMappingContext> DefaultMappingContext = nullptr;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Input")
    TObjectPtr<UInputAction> IA_Move = nullptr;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Input")
    TObjectPtr<UInputAction> IA_Look = nullptr;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Input")
    TObjectPtr<UInputAction> IA_Sprint = nullptr;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Input")
    TObjectPtr<UInputAction> IA_Interact = nullptr;

    UPROPERTY(BlueprintReadOnly, Category = "MountHope|Character")
    TObjectPtr<AMountHopeVehiclePawn> CurrentVehicle = nullptr;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Character")
    float VehicleInteractRange = 350.0f;

private:
    void InputMove(const FInputActionValue& Value);
    void InputLook(const FInputActionValue& Value);
    void InputSprintStart(const FInputActionValue& Value);
    void InputSprintStop(const FInputActionValue& Value);
    void InputInteract(const FInputActionValue& Value);
    AMountHopeVehiclePawn* FindNearestVehicle() const;
};
