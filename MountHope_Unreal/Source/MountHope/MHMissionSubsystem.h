#pragma once

#include "CoreMinimal.h"
#include "GameplayTagContainer.h"
#include "Subsystems/WorldSubsystem.h"
#include "MHMissionSubsystem.generated.h"

UCLASS()
class MOUNTHOPE_API UMHMissionSubsystem : public UWorldSubsystem
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Missions")
    bool StartMission(FGameplayTag MissionTag);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Missions")
    bool CompleteMission(FGameplayTag MissionTag);

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Missions")
    bool IsMissionActive(FGameplayTag MissionTag) const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Missions")
    bool IsMissionComplete(FGameplayTag MissionTag) const;

private:
    UPROPERTY()
    FGameplayTagContainer ActiveMissions;

    UPROPERTY()
    FGameplayTagContainer CompletedMissions;
};
