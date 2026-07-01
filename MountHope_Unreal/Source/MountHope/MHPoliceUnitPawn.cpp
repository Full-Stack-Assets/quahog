#include "MHPoliceUnitPawn.h"

#include "Components/StaticMeshComponent.h"
#include "Kismet/GameplayStatics.h"
#include "MHGameStateSubsystem.h"

AMHPoliceUnitPawn::AMHPoliceUnitPawn()
{
    PrimaryActorTick.bCanEverTick = true;

    BodyMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyMesh"));
    RootComponent = BodyMesh;
    BodyMesh->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    BodyMesh->SetCollisionResponseToAllChannels(ECR_Ignore);
    BodyMesh->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
}

void AMHPoliceUnitPawn::BeginPlay()
{
    Super::BeginPlay();

    if (SirenSound)
    {
        SirenAudioComponent = UGameplayStatics::SpawnSoundAttached(SirenSound, RootComponent);
    }
}

void AMHPoliceUnitPawn::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    TimeSinceLastCatch += DeltaSeconds;

    APawn* PlayerPawn = UGameplayStatics::GetPlayerPawn(GetWorld(), 0);
    if (!PlayerPawn)
    {
        return;
    }

    const FVector ToPlayer = PlayerPawn->GetActorLocation() - GetActorLocation();
    const FVector Direction = ToPlayer.GetSafeNormal();

    SetActorLocation(GetActorLocation() + Direction * ChaseSpeed * DeltaSeconds);
    if (!Direction.IsNearlyZero())
    {
        SetActorRotation(Direction.Rotation());
    }

    TryCatchPlayer(PlayerPawn);
}

void AMHPoliceUnitPawn::TryCatchPlayer(APawn* PlayerPawn)
{
    if (TimeSinceLastCatch < RepeatCatchCooldownSeconds)
    {
        return;
    }

    if (FVector::DistSquared(GetActorLocation(), PlayerPawn->GetActorLocation()) > FMath::Square(CatchRadius))
    {
        return;
    }

    TimeSinceLastCatch = 0.0f;

    if (UGameInstance* GameInstance = GetGameInstance())
    {
        if (UMHGameStateSubsystem* GameState = GameInstance->GetSubsystem<UMHGameStateSubsystem>())
        {
            GameState->ApplyDamage(CatchDamage);
        }
    }
}
