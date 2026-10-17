import { render, screen } from '@testing-library/react'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { describe, expect, it } from 'vitest'

import { routes } from '../router'

describe('HomePage', () => {
  it('shows the couple and year at /', () => {
    const router = createMemoryRouter(routes, { initialEntries: ['/'] })

    render(<RouterProvider router={router} />)

    expect(
      screen.getByRole('heading', { name: 'Charlie & Catie 2027' }),
    ).toBeInTheDocument()
  })
})
