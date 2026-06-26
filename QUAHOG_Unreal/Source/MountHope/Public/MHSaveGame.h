#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "MHSaveGame.generated.h"

UCLASS()
class MOUNTHOPE_API UMHSaveGame : public USaveGame
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "MountHope|Save")
    int32 Cash = 250;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "MountHope|Save")
    float Health = 100.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "MountHope|Save")
    float PoliceHeat = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "MountHope|Save")
    float FactionHeat = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "MountHope|Save")
    uint8 Weather = 0;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "MountHope|Save")
    TArray<FString> OwnedBusinessIds;
};
