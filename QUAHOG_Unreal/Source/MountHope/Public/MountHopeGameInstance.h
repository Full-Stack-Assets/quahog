#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstance.h"
#include "MountHopeGameInstance.generated.h"

UCLASS()
class MOUNTHOPE_API UMountHopeGameInstance : public UGameInstance
{
    GENERATED_BODY()

public:
    virtual void Init() override;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Boot")
    FString SlicePath = TEXT("../QUAHOG_Web/public/slice-newbedford.json");

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Boot")
    FString MissionPath = TEXT("Data/Missions/vertical_slice.json");

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Boot")
    FString EconomyPath = TEXT("Data/Economy/businesses.json");
};
