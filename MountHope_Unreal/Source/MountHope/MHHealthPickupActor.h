#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MHHealthPickupActor.generated.h"

class USphereComponent;
class UStaticMeshComponent;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHHealthPickupActor : public AActor
{
    GENERATED_BODY()

public:
    AMHHealthPickupActor();

protected:
    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Health")
    TObjectPtr<USphereComponent> PickupSphere;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Health")
    TObjectPtr<UStaticMeshComponent> DisplayMesh;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Health")
    float HealAmount = 40.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Health")
    float RespawnCooldownSeconds = 30.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Health")
    float PickupRadius = 120.0f;

    UFUNCTION()
    void OnPickupOverlap(
        UPrimitiveComponent* OverlappedComponent,
        AActor* OtherActor,
        UPrimitiveComponent* OtherComp,
        int32 OtherBodyIndex,
        bool bFromSweep,
        const FHitResult& SweepResult);

private:
    void Respawn();

    FTimerHandle RespawnTimerHandle;
};
