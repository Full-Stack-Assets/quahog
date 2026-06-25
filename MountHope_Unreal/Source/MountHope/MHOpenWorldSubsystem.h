#pragma once

#include "CoreMinimal.h"
#include "Subsystems/WorldSubsystem.h"
#include "MHOpenWorldSubsystem.generated.h"

USTRUCT(BlueprintType)
struct FMHMapSourceProfile
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|World")
    FName Name = NAME_None;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|World")
    FString SourcePath;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|World")
    float MetersToUnrealUnits = 100.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|World")
    bool bAllowFictionalizedEdits = true;
};

UCLASS()
class MOUNTHOPE_API UMHOpenWorldSubsystem : public UWorldSubsystem
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintPure, Category = "Mount Hope|World")
    FMHMapSourceProfile GetDefaultMapSource() const;
};
