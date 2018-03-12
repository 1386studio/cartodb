<section>
  <header class="ApiKeysForm-title">
    <button class="js-back">
      <i class="CDB-IconFont CDB-IconFont-arrowPrev u-actionTextColor u-rSpace--xl"></i>
    </button>
    <h3 class="CDB-Text CDB-Size-medium is-semibold u-mainTextColor">
      <% if (modelIsNew) { %>
        Configure your key
      <% } else { %>
        Your API key details
      <% } %>
    </h3>
  </header>

  <div class="js-api-keys-form"></div>
  <div class="js-api-keys-tables"></div>

  <footer class="FormAccount-footer">
    <p class="FormAccount-footerText">Changes to the key permissions are not possible once key is generated</p>
    <% if (modelIsNew) { %>
      <button type="submit" class="CDB-Button CDB-Button--primary is-disabled js-submit">
        <span class="CDB-Button-Text CDB-Text is-semibold CDB-Size-small u-upperCase">Save changes</span>
      </button>
    <% } %>
  </footer>
</section>
