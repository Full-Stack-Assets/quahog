#include "MHDialogueSubsystem.h"

void UMHDialogueSubsystem::BeginConversation(FName ConversationId, const TArray<FMHDialogueLine>& Lines)
{
    ActiveConversationId = ConversationId;
    ActiveLines = Lines;
    ActiveLineIndex = ActiveLines.Num() > 0 ? 0 : INDEX_NONE;
}

bool UMHDialogueSubsystem::AdvanceConversation()
{
    if (!IsConversationActive())
    {
        return false;
    }

    ++ActiveLineIndex;
    if (!ActiveLines.IsValidIndex(ActiveLineIndex))
    {
        ActiveConversationId = NAME_None;
        ActiveLines.Reset();
        ActiveLineIndex = INDEX_NONE;
        return false;
    }

    return true;
}

bool UMHDialogueSubsystem::IsConversationActive() const
{
    return ActiveConversationId != NAME_None && ActiveLines.IsValidIndex(ActiveLineIndex);
}

FMHDialogueLine UMHDialogueSubsystem::GetCurrentLine() const
{
    return IsConversationActive() ? ActiveLines[ActiveLineIndex] : FMHDialogueLine();
}
