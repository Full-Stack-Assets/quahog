#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "MHMissionSubsystem.generated.h"

USTRUCT(BlueprintType)
struct FMHMissionStep
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    FString Text;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    FVector Target = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    float Radius = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    bool bNeedVehicle = false;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    int32 Reward = 0;
};

USTRUCT(BlueprintType)
struct FMHMission
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    FString Title;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    TArray<FMHMissionStep> Steps;
};

UCLASS(BlueprintType)
class MOUNTHOPE_API UMHMissionSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    TArray<FMHMission> Missions;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    int32 MissionIndex = 0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    int32 StepIndex = 0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    bool bCampaignComplete = false;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Mission")
    bool LoadMissionsFromJson(const FString& RelativeOrAbsolutePath);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Mission")
    void ResetCampaign();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Mission")
    bool AdvanceStep();

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Mission")
    bool GetCurrentMission(FMHMission& OutMission) const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Mission")
    bool GetCurrentStep(FMHMissionStep& OutStep) const;
};
