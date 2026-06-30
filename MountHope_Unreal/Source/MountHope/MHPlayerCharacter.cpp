#include "MHPlayerCharacter.h"

#include "Camera/CameraComponent.h"
#include "Components/InputComponent.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/SpringArmComponent.h"
#include "MHGameModeBase.h"
#include "MHInteractable.h"
#include "MHVehiclePawn.h"

AMHPlayerCharacter::AMHPlayerCharacter()
{
    PrimaryActorTick.bCanEverTick = true;

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(RootComponent);
    CameraBoom->TargetArmLength = 450.0f;
    CameraBoom->bUsePawnControlRotation = true;

    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;

    bUseControllerRotationYaw = false;
    GetCharacterMovement()->bOrientRotationToMovement = true;
    GetCharacterMovement()->RotationRate = FRotator(0.0f, 540.0f, 0.0f);
    GetCharacterMovement()->MaxWalkSpeed = 450.0f;
    GetCharacterMovement()->BrakingDecelerationWalking = 1800.0f;
}

void AMHPlayerCharacter::BeginPlay()
{
    Super::BeginPlay();
}

void AMHPlayerCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
}

void AMHPlayerCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);

    PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &AMHPlayerCharacter::MoveForward);
    PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &AMHPlayerCharacter::MoveRight);
    PlayerInputComponent->BindAxis(TEXT("Turn"), this, &AMHPlayerCharacter::Turn);
    PlayerInputComponent->BindAxis(TEXT("LookUp"), this, &AMHPlayerCharacter::LookUp);
    PlayerInputComponent->BindAction(TEXT("Interact"), IE_Pressed, this, &AMHPlayerCharacter::TryInteract);
    PlayerInputComponent->BindAction(TEXT("EnterExitVehicle"), IE_Pressed, this, &AMHPlayerCharacter::RequestEnterExitVehicle);
}

void AMHPlayerCharacter::TryInteract()
{
    if (bInVehicle)
    {
        ExitVehicle();
        return;
    }

    if (AMHVehiclePawn* NearbyVehicle = FindNearestVehicle())
    {
        EnterVehicle(NearbyVehicle);
        return;
    }

    TArray<FOverlapResult> Overlaps;
    const float RadiusUnrealUnits = InteractionRadiusMeters * 100.0f;
    const FCollisionShape InteractionShape = FCollisionShape::MakeSphere(RadiusUnrealUnits);
    FCollisionObjectQueryParams ObjectTypes;
    ObjectTypes.AddObjectTypesToQuery(ECC_Pawn);
    ObjectTypes.AddObjectTypesToQuery(ECC_WorldDynamic);

    if (!GetWorld()->OverlapMultiByObjectType(Overlaps, GetActorLocation(), FQuat::Identity, ObjectTypes, InteractionShape))
    {
        return;
    }

    for (const FOverlapResult& Overlap : Overlaps)
    {
        AActor* Candidate = Overlap.GetActor();
        if (Candidate != nullptr && Candidate != this && Candidate->GetClass()->ImplementsInterface(UMHInteractable::StaticClass()))
        {
            IMHInteractable::Execute_Interact(Candidate, this);
            return;
        }
    }
}

void AMHPlayerCharacter::RequestEnterExitVehicle()
{
    if (bInVehicle)
    {
        ExitVehicle();
        return;
    }

    if (AMHVehiclePawn* NearbyVehicle = FindNearestVehicle())
    {
        EnterVehicle(NearbyVehicle);
    }
}

bool AMHPlayerCharacter::EnterVehicle(AMHVehiclePawn* VehiclePawn)
{
    if (bInVehicle || !VehiclePawn || !Controller)
    {
        return false;
    }

    if (!VehiclePawn->CanDriverEnter(this))
    {
        return false;
    }

    CurrentVehicle = VehiclePawn;
    bInVehicle = true;

    SetActorEnableCollision(false);
    SetActorHiddenInGame(true);
    Controller->Possess(VehiclePawn);

    if (AMHGameModeBase* GameMode = GetWorld() ? Cast<AMHGameModeBase>(GetWorld()->GetAuthGameMode()) : nullptr)
    {
        GameMode->TryCompleteVehicleObjective(true);
    }

    return true;
}

bool AMHPlayerCharacter::ExitVehicle()
{
    if (!bInVehicle || !CurrentVehicle || !Controller)
    {
        return false;
    }

    const FVector ExitLocation = CurrentVehicle->GetSuggestedExitLocation();
    SetActorLocation(ExitLocation);
    SetActorEnableCollision(true);
    SetActorHiddenInGame(false);
    Controller->Possess(this);

    bInVehicle = false;
    CurrentVehicle = nullptr;
    return true;
}

void AMHPlayerCharacter::MoveForward(float Value)
{
    if (Controller == nullptr || FMath::IsNearlyZero(Value) || bInVehicle)
    {
        return;
    }

    const FRotator YawRotation(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
    AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::X), Value);
}

void AMHPlayerCharacter::MoveRight(float Value)
{
    if (Controller == nullptr || FMath::IsNearlyZero(Value) || bInVehicle)
    {
        return;
    }

    const FRotator YawRotation(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
    AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::Y), Value);
}

void AMHPlayerCharacter::Turn(float Value)
{
    AddControllerYawInput(Value);
}

void AMHPlayerCharacter::LookUp(float Value)
{
    AddControllerPitchInput(Value);
}

AMHVehiclePawn* AMHPlayerCharacter::FindNearestVehicle() const
{
    if (!GetWorld())
    {
        return nullptr;
    }

    AMHVehiclePawn* BestVehicle = nullptr;
    float BestDistSq = VehicleInteractRange * VehicleInteractRange;
    const FVector MyLoc = GetActorLocation();

    for (TActorIterator<AMHVehiclePawn> It(GetWorld()); It; ++It)
    {
        AMHVehiclePawn* Candidate = *It;
        if (!IsValid(Candidate))
        {
            continue;
        }

        const float DistSq = FVector::DistSquared(MyLoc, Candidate->GetActorLocation());
        if (DistSq <= BestDistSq)
        {
            BestDistSq = DistSq;
            BestVehicle = Candidate;
        }
    }

    return BestVehicle;
}
