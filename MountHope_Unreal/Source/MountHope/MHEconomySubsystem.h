#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "MHEconomySubsystem.generated.h"

UCLASS()
class MOUNTHOPE_API UMHEconomySubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Economy")
    int32 GetCashBalance() const;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Economy")
    void AddCash(int32 Amount, FName Reason);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Economy")
    bool SpendCash(int32 Amount, FName Reason);

private:
    UPROPERTY()
    int32 CashBalance = 120;
};
