#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "MHWorldSliceTypes.h"
#include "MHWorldSliceSubsystem.generated.h"

UCLASS(BlueprintType)
class MOUNTHOPE_API UMHWorldSliceSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    FString SliceName;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    TArray<FMHRoadRecord> Roads;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    TArray<FMHBuildingRecord> Buildings;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    TArray<FMHLandmarkRecord> Landmarks;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    FVector2D OriginLatLon = FVector2D::ZeroVector;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|World")
    bool LoadSliceFromJson(const FString& RelativeOrAbsolutePath);

    UFUNCTION(BlueprintPure, Category = "Mount Hope|World")
    bool IsSliceLoaded() const;
};
