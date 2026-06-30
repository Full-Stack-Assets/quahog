#pragma once

#include "CoreMinimal.h"
#include "Subsystems/WorldSubsystem.h"
#include "MHDialogueSubsystem.generated.h"

USTRUCT(BlueprintType)
struct FMHDialogueLine
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Dialogue")
    FName SpeakerId = NAME_None;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Dialogue")
    FText SpeakerName;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Dialogue")
    FText Line;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Dialogue")
    float MinimumDisplaySeconds = 2.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Dialogue")
    bool bCanSkip = true;
};

UCLASS()
class MOUNTHOPE_API UMHDialogueSubsystem : public UWorldSubsystem
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Dialogue")
    void BeginConversation(FName ConversationId, const TArray<FMHDialogueLine>& Lines);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Dialogue")
    bool AdvanceConversation();

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Dialogue")
    bool IsConversationActive() const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Dialogue")
    FMHDialogueLine GetCurrentLine() const;

private:
    UPROPERTY()
    FName ActiveConversationId = NAME_None;

    UPROPERTY()
    TArray<FMHDialogueLine> ActiveLines;

    UPROPERTY()
    int32 ActiveLineIndex = INDEX_NONE;
};
