#include "MHCollectibleActor.h"

#include "Components/SphereComponent.h"
#include "Components/StaticMeshComponent.h"
#include "MHCollectibleSubsystem.h"
#include "MHGameStateSubsystem.h"

AMHCollectibleActor::AMHCollectibleActor()
{
    PrimaryActorTick.bCanEverTick = false;

    InteractionSphere = CreateDefaultSubobject<USphereComponent>(TEXT("InteractionSphere"));
    RootComponent = InteractionSphere;
    InteractionSphere->SetSphereRadius(InteractionRadius);
    InteractionSphere->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    InteractionSphere->SetCollisionResponseToAllChannels(ECR_Ignore);
    InteractionSphere->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);

    DisplayMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("DisplayMesh"));
    DisplayMesh->SetupAttachment(RootComponent);
    DisplayMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
}

void AMHCollectibleActor::BeginPlay()
{
    Super::BeginPlay();

    InteractionSphere->SetSphereRadius(InteractionRadius);
    RefreshVisibilityForCollectedState();
}

FText AMHCollectibleActor::GetInteractionPrompt_Implementation() const
{
    UGameInstance* GameInstance = GetGameInstance();
    if (GameInstance)
    {
        if (UMHCollectibleSubsystem* Collectibles = GameInstance->GetSubsystem<UMHCollectibleSubsystem>())
        {
            FMHCollectibleRecord Record;
            if (Collectibles->FindCollectible(ItemId, Record) && !Record.DisplayName.IsEmpty())
            {
                return FText::FromString(FString::Printf(TEXT("Pick up %s"), *Record.DisplayName));
            }
        }
    }

    return FText::FromString(TEXT("Pick up item"));
}

void AMHCollectibleActor::Interact_Implementation(APawn* InstigatorPawn)
{
    if (!InstigatorPawn || ItemId.IsNone())
    {
        return;
    }

    UGameInstance* GameInstance = GetGameInstance();
    if (!GameInstance)
    {
        return;
    }

    UMHCollectibleSubsystem* Collectibles = GameInstance->GetSubsystem<UMHCollectibleSubsystem>();
    if (!Collectibles || Collectibles->IsCollected(ItemId))
    {
        return;
    }

    FMHCollectibleRecord Record;
    if (!Collectibles->FindCollectible(ItemId, Record))
    {
        return;
    }

    if (!Collectibles->CollectItem(ItemId))
    {
        return;
    }

    if (Record.CashReward != 0)
    {
        if (UMHGameStateSubsystem* GameState = GameInstance->GetSubsystem<UMHGameStateSubsystem>())
        {
            GameState->AddCash(Record.CashReward);
        }
    }

    RefreshVisibilityForCollectedState();
}

void AMHCollectibleActor::RefreshVisibilityForCollectedState()
{
    UGameInstance* GameInstance = GetGameInstance();
    if (!GameInstance)
    {
        return;
    }

    UMHCollectibleSubsystem* Collectibles = GameInstance->GetSubsystem<UMHCollectibleSubsystem>();
    const bool bAlreadyCollected = Collectibles && Collectibles->IsCollected(ItemId);

    SetActorHiddenInGame(bAlreadyCollected);
    SetActorEnableCollision(!bAlreadyCollected);
}
