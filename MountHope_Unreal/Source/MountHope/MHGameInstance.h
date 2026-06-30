#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstance.h"
#include "MHGameInstance.generated.h"

UCLASS()
class MOUNTHOPE_API UMHGameInstance : public UGameInstance
{
    GENERATED_BODY()

public:
    virtual void Init() override;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Boot")
    FString SlicePath = TEXT("../QUAHOG_Web/public/slice-newbedford.json");

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Boot")
    FString MissionPath = TEXT("Data/Missions/vertical_slice.json");

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Boot")
    FString EconomyPath = TEXT("Data/Economy/businesses.json");

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Boot")
    FString DialoguePath = TEXT("Data/Dialogue/vertical_slice.json");

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Boot")
    FString SaveSlotName = TEXT("MountHopeSlot");
};
