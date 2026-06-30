#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "MHSaveSubsystem.generated.h"

class UMHSaveGame;

UCLASS()
class MOUNTHOPE_API UMHSaveSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Save")
    UMHSaveGame* CreateNewGameState();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Save")
    UMHSaveGame* LoadGameState();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Save")
    bool SaveGameState(UMHSaveGame* SaveGame);

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Save")
    FString GetDefaultSlotName() const;

private:
    UPROPERTY()
    FString DefaultSlotName = TEXT("MountHope_Autosave");

    UPROPERTY()
    int32 DefaultUserIndex = 0;
};
