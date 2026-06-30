#pragma once

#include "CoreMinimal.h"
#include "MHDialogueTypes.generated.h"

USTRUCT(BlueprintType)
struct FMHDialogueLine
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    FString Text;
};

USTRUCT(BlueprintType)
struct FMHDialogueCompletion
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    bool bCompleteObjective = false;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    bool bRequireOnFoot = true;
};

USTRUCT(BlueprintType)
struct FMHDialogueConversation
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    FName ConversationId = NAME_None;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    FString Speaker;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    FString Prompt;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    TArray<FMHDialogueLine> Lines;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    FMHDialogueCompletion OnComplete;
};
