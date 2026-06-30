#include "MHDialogueNpcActor.h"

#include "Components/SphereComponent.h"
#include "MHDialogueSubsystem.h"
#include "MHPlayerCharacter.h"
#include "MHVehiclePawn.h"

AMHDialogueNpcActor::AMHDialogueNpcActor()
{
    PrimaryActorTick.bCanEverTick = false;

    InteractionSphere = CreateDefaultSubobject<USphereComponent>(TEXT("InteractionSphere"));
    RootComponent = InteractionSphere;
    InteractionSphere->SetSphereRadius(InteractionRadius);
    InteractionSphere->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    InteractionSphere->SetCollisionResponseToAllChannels(ECR_Ignore);
    InteractionSphere->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
}

void AMHDialogueNpcActor::BeginPlay()
{
    Super::BeginPlay();
    InteractionSphere->SetSphereRadius(InteractionRadius);
}

FText AMHDialogueNpcActor::GetInteractionPrompt_Implementation() const
{
    if (!InteractionPromptOverride.IsEmpty())
    {
        return FText::FromString(InteractionPromptOverride);
    }

    return FText::FromString(FString::Printf(TEXT("Talk to %s"), *SpeakerDisplayName));
}

void AMHDialogueNpcActor::Interact_Implementation(APawn* InstigatorPawn)
{
    if (!InstigatorPawn || ConversationId == NAME_None)
    {
        return;
    }

    AdvanceOrStartDialogue(InstigatorPawn);
}

void AMHDialogueNpcActor::AdvanceOrStartDialogue(APawn* InstigatorPawn)
{
    UGameInstance* GameInstance = GetGameInstance();
    if (!GameInstance)
    {
        return;
    }

    UMHDialogueSubsystem* DialogueSubsystem = GameInstance->GetSubsystem<UMHDialogueSubsystem>();
    if (!DialogueSubsystem)
    {
        return;
    }

    const bool bInVehicle = InstigatorPawn->IsA<AMHVehiclePawn>();

    if (DialogueSubsystem->IsConversationActive())
    {
        FMHDialogueConversation ActiveConversation;
        if (DialogueSubsystem->GetActiveConversation(ActiveConversation)
            && ActiveConversation.ConversationId == ConversationId)
        {
            DialogueSubsystem->AdvanceConversation(bInVehicle);
            return;
        }
    }

    DialogueSubsystem->StartConversation(ConversationId);
}
