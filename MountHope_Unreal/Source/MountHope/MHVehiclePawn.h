#pragma once

#include "CoreMinimal.h"
#include "WheeledVehiclePawn.h"
#include "MHVehiclePawn.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FMHOnVehicleHealthChanged, float, HealthPercent, bool, bWrecked);

UCLASS()
class MOUNTHOPE_API AMHVehiclePawn : public AWheeledVehiclePawn
{
    GENERATED_BODY()

public:
    AMHVehiclePawn();

    virtual void NotifyHit(
        UPrimitiveComponent* MyComp,
        AActor* Other,
        UPrimitiveComponent* OtherComp,
        bool bSelfMoved,
        FVector HitLocation,
        FVector HitNormal,
        FVector NormalImpulse,
        const FHitResult& Hit) override;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Vehicle")
    bool CanDriverEnter(const APawn* CandidateDriver) const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Vehicle")
    FVector GetSuggestedExitLocation() const;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Vehicle|Damage")
    void ApplyVehicleDamage(float Damage);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Vehicle|Damage")
    void RepairVehicle();

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Vehicle|Damage")
    float GetHealthPercent() const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Vehicle|Damage")
    bool IsWrecked() const { return bWrecked; }

    UPROPERTY(BlueprintAssignable, Category = "Mount Hope|Vehicle|Damage")
    FMHOnVehicleHealthChanged OnVehicleHealthChanged;

protected:
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Vehicle")
    float EntryRadiusMeters = 3.5f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Vehicle|Damage")
    float MaxHealth = 100.0f;

    UPROPERTY(BlueprintReadOnly, Category = "Mount Hope|Vehicle|Damage")
    float Health = 100.0f;

    UPROPERTY(BlueprintReadOnly, Category = "Mount Hope|Vehicle|Damage")
    bool bWrecked = false;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Vehicle|Damage")
    float CollisionDamageThreshold = 900.0f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Vehicle|Damage")
    float CollisionDamageScale = 0.05f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Vehicle|Tuning")
    float VehicleMassKg = 2200.0f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Vehicle|Tuning")
    float DragCoefficient = 0.38f;

private:
    void ApplyHeavyVehicleTuning();
};
