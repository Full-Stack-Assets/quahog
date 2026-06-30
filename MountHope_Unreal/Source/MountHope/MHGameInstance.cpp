#include "MHGameInstance.h"

#include "MHDialogueSubsystem.h"
#include "MHGameStateSubsystem.h"
#include "MHMissionSubsystem.h"
#include "MHWorldSliceSubsystem.h"

void UMHGameInstance::Init()
{
    Super::Init();

    if (UMHWorldSliceSubsystem* SliceSubsystem = GetSubsystem<UMHWorldSliceSubsystem>())
    {
        SliceSubsystem->LoadSliceFromJson(SlicePath);
    }

    if (UMHMissionSubsystem* MissionSubsystem = GetSubsystem<UMHMissionSubsystem>())
    {
        MissionSubsystem->LoadMissionsFromJson(MissionPath);
    }

    if (UMHDialogueSubsystem* DialogueSubsystem = GetSubsystem<UMHDialogueSubsystem>())
    {
        DialogueSubsystem->LoadDialogueFromJson(DialoguePath);
    }

    if (UMHGameStateSubsystem* GameStateSubsystem = GetSubsystem<UMHGameStateSubsystem>())
    {
        GameStateSubsystem->LoadBusinessesFromJson(EconomyPath);
        GameStateSubsystem->LoadFromSlot(SaveSlotName);
    }
}
