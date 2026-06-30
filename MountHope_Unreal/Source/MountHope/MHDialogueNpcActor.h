#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MHInteractable.h"
#include "MHDialogueNpcActor.generated.h"

class USphereComponent;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHDialogueNpcActor : public AActor, public IMHInteractable
{
    GENERATED_BODY()

public:
    AMHDialogueNpcActor();

    virtual FText GetInteractionPrompt_Implementation() const override;
    virtual void Interact_Implementation(APawn* InstigatorPawn) override;

protected:
    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    TObjectPtr<USphereComponent> InteractionSphere;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    FName ConversationId = NAME_None;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    FString SpeakerDisplayName = TEXT("NPC");

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    FString InteractionPromptOverride;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Dialogue")
    float InteractionRadius = 275.0f;

private:
    void AdvanceOrStartDialogue(APawn* InstigatorPawn);
};
