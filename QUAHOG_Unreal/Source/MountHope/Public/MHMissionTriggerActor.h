#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MHMissionTriggerActor.generated.h"

class USphereComponent;
class UPrimitiveComponent;
struct FHitResult;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHMissionTriggerActor : public AActor
{
    GENERATED_BODY()

public:
    AMHMissionTriggerActor();

    UFUNCTION(BlueprintCallable, Category = "MountHope|Mission")
    void SetTriggerRadius(float NewRadius);

    UFUNCTION(BlueprintCallable, Category = "MountHope|Mission")
    void ResetConsumed();

protected:
    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "MountHope|Mission")
    TObjectPtr<USphereComponent> TriggerSphere;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Mission")
    bool bOneShot = true;

    UFUNCTION()
    void OnTriggerOverlap(
        UPrimitiveComponent* OverlappedComponent,
        AActor* OtherActor,
        UPrimitiveComponent* OtherComp,
        int32 OtherBodyIndex,
        bool bFromSweep,
        const FHitResult& SweepResult);

    bool bConsumed = false;
};
