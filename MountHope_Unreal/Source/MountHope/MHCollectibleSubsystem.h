#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "MHCollectibleSubsystem.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FMHOnCollectibleFound, FName, ItemId, int32, CollectedCount, int32, TotalCount);

USTRUCT(BlueprintType)
struct FMHCollectibleRecord
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Collectible")
    FName Id;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Collectible")
    FString DisplayName;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Collectible")
    FString FlavorText;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Collectible")
    int32 CashReward = 25;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Collectible")
    FVector WorldLocation = FVector::ZeroVector;
};

UCLASS(BlueprintType)
class MOUNTHOPE_API UMHCollectibleSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UPROPERTY(BlueprintAssignable, Category = "Mount Hope|Collectible")
    FMHOnCollectibleFound OnCollectibleFound;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Collectible")
    TArray<FMHCollectibleRecord> Collectibles;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Collectible")
    bool LoadCollectiblesFromJson(const FString& RelativeOrAbsolutePath);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Collectible")
    bool CollectItem(FName ItemId);

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Collectible")
    bool IsCollected(FName ItemId) const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Collectible")
    bool FindCollectible(FName ItemId, FMHCollectibleRecord& OutRecord) const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Collectible")
    int32 GetCollectedCount() const { return CollectedIds.Num(); }

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Collectible")
    int32 GetTotalCount() const { return Collectibles.Num(); }

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Collectible")
    TArray<FString> GetCollectedIdsAsStrings() const;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Collectible")
    void RestoreCollectedIds(const TArray<FString>& SavedIds);

private:
    UPROPERTY()
    TSet<FName> CollectedIds;
};
