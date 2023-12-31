using Unity.Burst;
using Unity.Burst.Intrinsics;
using Unity.CharacterController;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Physics;
using Unity.Transforms;
using UnityEngine;

[BurstCompile]
[UpdateInGroup(typeof(SimulationSystemGroup))]
public partial struct AIControllerSystem : ISystem
{
    EntityQuery _enemyQuery;

    [BurstCompile]
    public void OnCreate(ref SystemState state)
    {
        EntityQueryBuilder builder = new EntityQueryBuilder(Allocator.Temp)
            .WithAll<LocalTransform, ThirdPersonCharacterControl, AIData, CharacterState>();
        _enemyQuery = state.GetEntityQuery(builder);
        state.RequireForUpdate(_enemyQuery);
    }

    [BurstCompile]
    public void OnUpdate(ref SystemState state)
    {
        var position = SystemAPI.GetComponent<LocalTransform>(SystemAPI.GetSingletonEntity<PlayerTag>()).Position;
        state.Dependency = new QueryJob()
        {
            TargetPosition = position,
            DeltaTime = SystemAPI.Time.DeltaTime
        }.ScheduleParallel(_enemyQuery, state.Dependency);
    }

    [BurstCompile]
    partial struct QueryJob : IJobEntity
    {
        public float3 TargetPosition;
        public float DeltaTime;

        public void Execute(ref ThirdPersonCharacterControl characterControl, ref LocalTransform localTransform, ref CharacterState stateData, in AIData aiController)
        {
            stateData.IntervalAttack -= DeltaTime;
            var distance = math.distance(TargetPosition, localTransform.Position);
            if (distance <= aiController.AttackRange)
            {
                if (stateData.IntervalAttack <= 0f)
                {
                    characterControl.MoveVector = float3.zero;
                    stateData.Attack = true;
                }
                else
                {
                    characterControl.MoveVector = float3.zero;
                }
                localTransform.Rotation = quaternion.LookRotationSafe(math.normalize(TargetPosition - localTransform.Position), math.up());
            }
            else
                characterControl.MoveVector = math.normalizesafe(TargetPosition - localTransform.Position);
        }
    }
}