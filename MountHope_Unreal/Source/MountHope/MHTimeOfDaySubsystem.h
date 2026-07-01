#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "MHTimeOfDaySubsystem.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FMHOnHourChanged, int32, Hour);

UCLASS(BlueprintType)
class MOUNTHOPE_API UMHTimeOfDaySubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UPROPERTY(BlueprintAssignable, Category = "Mount Hope|Time")
    FMHOnHourChanged OnHourChanged;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Time")
    float CurrentHour = 8.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Time")
    float RealSecondsPerGameDay = 600.0f;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Time")
    void AdvanceTime(float DeltaSeconds);

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Time")
    float GetCurrentHour() const { return CurrentHour; }

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Time")
    bool IsNight() const { return CurrentHour < 6.0f || CurrentHour >= 19.0f; }

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Time")
    float GetSunIntensityMultiplier() const;

private:
    int32 LastBroadcastHour = INDEX_NONE;
};
