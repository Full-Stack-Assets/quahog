#pragma once

#include "CoreMinimal.h"
#include "GameplayTagContainer.h"
#include "GameFramework/SaveGame.h"
#include "MHSaveGame.generated.h"

UCLASS()
class MOUNTHOPE_API UMHSaveGame : public USaveGame
{
    GENERATED_BODY()

public:
    UPROPERTY(BlueprintReadWrite, Category = "Mount Hope|Save")
    FTransform PlayerTransform = FTransform::Identity;

    UPROPERTY(BlueprintReadWrite, Category = "Mount Hope|Save")
    FTransform VehicleTransform = FTransform::Identity;

    UPROPERTY(BlueprintReadWrite, Category = "Mount Hope|Save")
    int32 CashBalance = 0;

    UPROPERTY(BlueprintReadWrite, Category = "Mount Hope|Save")
    int32 WantedLevel = 0;

    UPROPERTY(BlueprintReadWrite, Category = "Mount Hope|Save")
    FGameplayTagContainer ActiveMissions;

    UPROPERTY(BlueprintReadWrite, Category = "Mount Hope|Save")
    FGameplayTagContainer CompletedMissions;

    UPROPERTY(BlueprintReadWrite, Category = "Mount Hope|Save")
    TMap<FName, int32> ReputationByFaction;

    UPROPERTY(BlueprintReadWrite, Category = "Mount Hope|Save")
    FName LastCheckpointId = NAME_None;
};
