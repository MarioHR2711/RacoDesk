<?php

namespace Tests\Feature;

use Tests\TestCase;

class HealthCheckTest extends TestCase
{
    /**
     * The framework health route answers when the application boots.
     * It does not touch the database.
     */
    public function test_health_route_returns_ok(): void
    {
        $response = $this->get('/up');

        $response->assertOk();
    }
}
