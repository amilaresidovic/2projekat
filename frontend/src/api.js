const BACKEND_URL = "/api";

export async function getContacts() {
  const response = await fetch(`${BACKEND_URL}/contacts`);
  return await response.json();
}

export async function createContact(contactData) {
  const response = await fetch(`${BACKEND_URL}/create_contact`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(contactData)
  });
  return await response.json();
}

export async function updateContact(id, contactData) {
  const response = await fetch(`${BACKEND_URL}/update_contact/${id}`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(contactData)
  });
  return await response.json();
}

export async function deleteContact(id) {
  const response = await fetch(`${BACKEND_URL}/delete_contact/${id}`, {
    method: "DELETE"
  });
  return await response.json();
}