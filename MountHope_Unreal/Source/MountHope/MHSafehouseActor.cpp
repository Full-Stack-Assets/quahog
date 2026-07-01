#include "MHSafehouseActor.h"

#include "Components/SphereComponent.h"
#include "MHGameStateSubsystem.h"
#include "MHWantedSubsystem.h"

AMHSafehouseActor::AMHSafehouseActor()
{
    PrimaryActorTick.bCanEverTick = false;

    InteractionSphere = CreateDefaultSubobject<USphereComponent>(TEXT("InteractionSphere"));
    RootComponent = InteractionSphere;
    InteractionSphere->SetSphereRadius(InteractionRadius);
    InteractionSphere->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    InteractionSphere->SetCollisionResponseToAllChannels(ECR_Ignore);
    InteractionSphere->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
}

void AMHSafehouseActor::BeginPlay()
{
    Super::BeginPlay();
    InteractionSphere->SetSphereRadius(InteractionRadius);
}

FText AMHSafehouseActor::GetInteractionPrompt_Implementation() const
{
    return FText::FromString(FString::Printf(TEXT("Save at %s"), *SafehouseName));
}

void AMHSafehouseActor::Interact_Implementation(APawn* InstigatorPawn)
{
    if (!InstigatorPawn)
    {
        return;
    }

    UGameInstance* GameInstance = GetGameInstance();
    if (!GameInstance)
    {
        return;
    }

    const FVector SafehouseLocation = GetActorLocation() + SpawnOffset;

    if (UMHGameStateSubsystem* GameState = GameInstance->GetSubsystem<UMHGameStateSubsystem>())
    {
        GameState->SetSafehouseLocation(SafehouseLocation);
        GameState->SaveToSlot();
    }

    if (UWorld* World = GetWorld())
    {
        if (UMHWantedSubsystem* Wanted = World->GetSubsystem<UMHWantedSubsystem>())
        {
            Wanted->ClearWantedState();
        }
    }

    UE_LOG(LogTemp, Log, TEXT("MountHope: Game saved at safehouse '%s'"), *SafehouseName);
}
