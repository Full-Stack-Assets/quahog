#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "MHPoliceUnitPawn.generated.h"

class UStaticMeshComponent;
class USoundBase;
class UAudioComponent;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHPoliceUnitPawn : public APawn
{
    GENERATED_BODY()

public:
    AMHPoliceUnitPawn();

    virtual void Tick(float DeltaSeconds) override;

protected:
    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    TObjectPtr<UStaticMeshComponent> BodyMesh;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float ChaseSpeed = 1400.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float CatchRadius = 350.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float CatchDamage = 8.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float RepeatCatchCooldownSeconds = 2.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Audio")
    TObjectPtr<USoundBase> SirenSound;

private:
    void TryCatchPlayer(APawn* PlayerPawn);

    UPROPERTY(Transient)
    TObjectPtr<UAudioComponent> SirenAudioComponent;

    float TimeSinceLastCatch = 999.0f;
};
