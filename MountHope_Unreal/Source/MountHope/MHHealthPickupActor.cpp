#include "MHHealthPickupActor.h"

#include "Components/SphereComponent.h"
#include "Components/StaticMeshComponent.h"
#include "MHGameStateSubsystem.h"
#include "MHPlayerCharacter.h"
#include "TimerManager.h"

AMHHealthPickupActor::AMHHealthPickupActor()
{
    PrimaryActorTick.bCanEverTick = false;

    PickupSphere = CreateDefaultSubobject<USphereComponent>(TEXT("PickupSphere"));
    RootComponent = PickupSphere;
    PickupSphere->SetSphereRadius(PickupRadius);
    PickupSphere->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    PickupSphere->SetCollisionResponseToAllChannels(ECR_Ignore);
    PickupSphere->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);

    DisplayMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("DisplayMesh"));
    DisplayMesh->SetupAttachment(RootComponent);
    DisplayMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
}

void AMHHealthPickupActor::BeginPlay()
{
    Super::BeginPlay();

    PickupSphere->SetSphereRadius(PickupRadius);
    PickupSphere->OnComponentBeginOverlap.AddDynamic(this, &AMHHealthPickupActor::OnPickupOverlap);
}

void AMHHealthPickupActor::OnPickupOverlap(
    UPrimitiveComponent* OverlappedComponent,
    AActor* OtherActor,
    UPrimitiveComponent* OtherComp,
    int32 OtherBodyIndex,
    bool bFromSweep,
    const FHitResult& SweepResult)
{
    if (!Cast<AMHPlayerCharacter>(OtherActor))
    {
        return;
    }

    UGameInstance* GameInstance = GetGameInstance();
    UMHGameStateSubsystem* GameState = GameInstance ? GameInstance->GetSubsystem<UMHGameStateSubsystem>() : nullptr;
    if (!GameState)
    {
        return;
    }

    GameState->Heal(HealAmount);

    SetActorEnableCollision(false);
    SetActorHiddenInGame(true);

    GetWorldTimerManager().SetTimer(RespawnTimerHandle, this, &AMHHealthPickupActor::Respawn, RespawnCooldownSeconds, false);
}

void AMHHealthPickupActor::Respawn()
{
    SetActorEnableCollision(true);
    SetActorHiddenInGame(false);
}
