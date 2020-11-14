defmodule Shopify.GraphQL.Limiter do
  @type name_t ::
          atom | { :global, any } | { :via, module, any }
end
