#include "MHSaveSubsystem.h"

#include "Kismet/GameplayStatics.h"
#include "MHSaveGame.h"

UMHSaveGame* UMHSaveSubsystem::CreateNewGameState()
{
    return Cast<UMHSaveGame>(UGameplayStatics::CreateSaveGameObject(UMHSaveGame::StaticClass()));
}

UMHSaveGame* UMHSaveSubsystem::LoadGameState()
{
    if (!UGameplayStatics::DoesSaveGameExist(DefaultSlotName, DefaultUserIndex))
    {
        return CreateNewGameState();
    }

    return Cast<UMHSaveGame>(UGameplayStatics::LoadGameFromSlot(DefaultSlotName, DefaultUserIndex));
}

bool UMHSaveSubsystem::SaveGameState(UMHSaveGame* SaveGame)
{
    if (SaveGame == nullptr)
    {
        return false;
    }

    return UGameplayStatics::SaveGameToSlot(SaveGame, DefaultSlotName, DefaultUserIndex);
}

FString UMHSaveSubsystem::GetDefaultSlotName() const
{
    return DefaultSlotName;
}
