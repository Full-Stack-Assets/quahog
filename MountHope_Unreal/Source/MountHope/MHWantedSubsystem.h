#pragma once

#include "CoreMinimal.h"
#include "Subsystems/WorldSubsystem.h"
#include "MHWantedSubsystem.generated.h"

UENUM(BlueprintType)
enum class EMHCrimeType : uint8
{
    TrafficViolation,
    Theft,
    Assault,
    PropertyDamage,
    MissionHeat
};

UCLASS()
class MOUNTHOPE_API UMHWantedSubsystem : public UWorldSubsystem
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Police")
    void ReportCrime(EMHCrimeType CrimeType, int32 Severity);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Police")
    void ReduceHeat(int32 Amount);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Police")
    void ClearWantedState();

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Police")
    int32 GetWantedLevel() const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Police")
    bool IsPoliceSearching() const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Police")
    int32 GetSuggestedFine() const;

private:
    UPROPERTY()
    int32 Heat = 0;

    UPROPERTY()
    int32 WantedLevel = 0;

    void RecalculateWantedLevel();
};
