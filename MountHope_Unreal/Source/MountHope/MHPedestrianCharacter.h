#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "MHPedestrianCharacter.generated.h"

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHPedestrianCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    AMHPedestrianCharacter();

    virtual void Tick(float DeltaSeconds) override;

protected:
    virtual void BeginPlay() override;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    float WanderRadiusMeters = 8.0f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    float MinWanderIntervalSeconds = 4.0f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    float MaxWanderIntervalSeconds = 9.0f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    float NormalWalkSpeed = 140.0f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    float FleeSpeed = 420.0f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    float ThreatDetectionRadiusMeters = 6.0f;

    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    float ThreatSpeedThreshold = 350.0f;

    UPROPERTY(BlueprintReadOnly, Category = "Mount Hope|Pedestrian")
    bool bIsFleeing = false;

private:
    void ScheduleNextWander();
    void PickNewWanderTarget();
    AActor* FindNearestThreat() const;
    void FleeFromThreat(const AActor* Threat);

    FVector HomeLocation = FVector::ZeroVector;
    FTimerHandle WanderTimerHandle;
};
