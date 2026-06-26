#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "MHPlayerCharacter.generated.h"

class USpringArmComponent;
class UCameraComponent;

UCLASS()
class MOUNTHOPE_API AMHPlayerCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AMHPlayerCharacter();

    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Interaction")
    void TryInteract();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Vehicle")
    void RequestEnterExitVehicle();

protected:
    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Camera")
    TObjectPtr<USpringArmComponent> CameraBoom;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Camera")
    TObjectPtr<UCameraComponent> FollowCamera;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Interaction")
    float InteractionRadiusMeters = 2.75f;

private:
    void MoveForward(float Value);
    void MoveRight(float Value);
    void Turn(float Value);
    void LookUp(float Value);
};
