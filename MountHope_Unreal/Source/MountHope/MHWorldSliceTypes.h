#pragma once

#include "CoreMinimal.h"
#include "MHWorldSliceTypes.generated.h"

USTRUCT(BlueprintType)
struct FMHPolyline2D
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    TArray<FVector2D> Points;
};

USTRUCT(BlueprintType)
struct FMHRoadRecord
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    FString Name;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    FString Highway;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    float Width = 7.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    FMHPolyline2D Centerline;
};

USTRUCT(BlueprintType)
struct FMHBuildingRecord
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    FString Name;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    float Height = 8.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    FMHPolyline2D Footprint;
};

USTRUCT(BlueprintType)
struct FMHLandmarkRecord
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    FString Name;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    FVector Location = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|World")
    bool bHero = false;
};
